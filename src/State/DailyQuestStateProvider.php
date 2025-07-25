<?php

namespace App\State;

use ApiPlatform\Metadata\CollectionOperationInterface;
use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\ApiResource\DailyQuest;
use App\ApiResource\QuestTreasure;
use App\Enum\DailyQuestStatusEnum;
use App\Repository\DragonTreasureRepository;

class DailyQuestStateProvider implements ProviderInterface
{
    public function __construct(
        private DragonTreasureRepository $dragonTreasureRepository,
    )
    {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): object|array|null
    {
        $quests = $this->createQuests();

        if ($operation instanceof CollectionOperationInterface) {
            return $quests;
        }

        return $quests[$uriVariables['dayString']] ?? null;
    }

    private function createQuests(): array
    {
        $treasures = $this->dragonTreasureRepository->findBy([], [], 10);

        $quests = [];
        for ($i = 0; $i < 50; $i++) {
            $quest = new DailyQuest(new \DateTimeImmutable(sprintf('- %d days', $i)));
            $quest->questName = sprintf('Quest %d', $i);
            $quest->description = sprintf('Description %d', $i);
            $quest->difficultyLevel = $i % 10;
            $quest->status = $i % 2 === 0 ? DailyQuestStatusEnum::ACTIVE : DailyQuestStatusEnum::COMPLETED;
            $quest->lastUpdated = new \DateTimeImmutable(sprintf('- %d days', random_int(10, 100)));

            $randomTreasuresKeys = array_rand($treasures, random_int(1, 3));
            $randomTreasures = array_map(
                static function($key) use ($treasures) {
                    $treasure = $treasures[$key];
                    return new QuestTreasure(
                        $treasure->getName(),
                        $treasure->getValue(),
                        $treasure->getCoolFactor(),
                    );
                },
                (array) $randomTreasuresKeys
            );
            $quest->treasures = $randomTreasures;

            $quests[$quest->getDayString()] = $quest;
        }
        return $quests;
    }
}
